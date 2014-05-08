;+
; NAME:
;       OMNI_EMAF_MORPH
;
; PURPOSE:
;       Perform morphological matching between SURVEY images and the
;       GLIMPSE 8um images.  This method uses a simple radiative
;       transfer model to create model 8-um images based on SURVEY
;       images and the estimated I_MIR.  By using the model of 8-um
;       foreground fraction derived from Robitatille et al. (2012,
;       A&A, 545, 39 -- described in Ellsworth-Bowers et al. 2013),
;       this routine creates model 8-um images as a function of
;       heliocentric distance.  Comparison of these model images with
;       the GLIMPSE image produces a likelihood as a function of
;       distance for a match.
;
; CATEGORY:
;       distance-omnibus DPDF Routine
;
; CALLING SEQUENCE:
;       prob = OMNI_EMAF_MORPH(struct [,/MAKE_PS])
;
; INPUTS:
;       STRUCT -- SURVEY source structure (see OMNI_READ_CATALOG.pro),
;                 which includes source longitude and latitude.
;
; OPTIONAL INPUTS:
;       TOPHAT -- Diameter of the top-hat restriction on the
;                 morphological matching region [arcsec].
;                 Default = 0 (i.e. no top-hat imposed)
;       Td     -- Dust temperature to use for conversion of BGPS
;                 flux density to 8-um optical depth.
;                 [Default = mw.Td]
;       FMEAS  -- Calculated f_meas for object in STRUCT (used for
;                 plotting).
;       MDIST  -- Model fit distance for object in STRUCT (used for
;                 plotting).
;       SUFF   -- Suffix (like "_q8") of the UBC_PROC images to be
;                 read in.  [Default = '']
;       CONFFILE -- Name of the configuration file to use for survey
;                   information [Default: conffiles/survey_info.conf]
;
; KEYWORD PARAMETERS:
;       MAKE_PS  -- Create postscript files containing the various
;                   images and plot of likelihood as a function of
;                   distance.  Creates files in the LOCAL.OUTPUT
;                   directory.
;       VERBOSE  -- Be verbose with output, including object # and
;                   statistics related to the TAUMAP.
;       CLEM     -- Use the Clemens (1985) rotation curve instead of
;                   the standard Reid (2009) curve.
;       BEAMMASK -- Use a Gaussian (33" FWHM) weighting on the
;                   chi^2 comparison between the model image and the
;                   smoothed GLIMPSE image.
;
; OUTPUTS:
;       PROB     -- Likehihood (or chisqr) as a function of distance
;                   for association between the BGPS image and the
;                   GLIMPSE 8-um image.
;
; OPTIONAL OUTPUTS:
;       NONE
;
; COMMON BLOCKS:
;       OMNI_CONFIG   -- The set of configuration structures, read in
;                        from the config files in conffiles/
;       POSTAGE_BLOCK -- Block holding the postage-stamp images loaded
;                        into memory by load_common_postage.pro.
;                        NOTE: Use of this block is optional, though
;                        it speed up execution.
;       CUBE_BLOCK    -- Block holding the FFORE data cube (l,b,d)
;                        needed to generate the DPDF.  If
;                        omni_load_ffore.pro is not called previous to
;                        this routine, it will be called here.
;                        Required.
;
; NOTES:
;       Requires EMAF-specific postage stamps generated by
;       omni_glimpse_emaf.pro, located in the directory specified by
;       local_layout.conf.
;
;
; MODIFICATION HISTORY:
;
;       Created:  09/08/11, TPEB -- Initial version, massaging
;                                   Erik Rosolowsky's routine
;                                   irdcdist.pro into the structure of
;                                   distance-omnibus.
;       Modified: 09/15/11, TPEB -- Added VERBOSE option, and fixed
;                                   bug in extracing LABELMAP
;                                   subsection for use.  Also, added
;                                   fix for UBC_GLIMPSE_PROC numbering
;                                   mishaps.
;       Modified: 02/27/12, TPEB -- Updated routine with all the
;                                   knowledge and work I've
;                                   done since September.
;       Modified: 03/01/12, TPEB -- Refining the prior PDF scheme, and
;                                   checking morphological matching of
;                                   objects in the IRDC modeling code
;                                   against the distance placement
;                                   done there.
;       Modified: 03/09/12, TPEB -- Added 'hyperfine' keyword to
;                                   OMNI_EMAF_MORPH_FFORE for the purposes
;                                   of a plot for the paper.
;       Modified: 03/26/12, TPEB -- Modified routine to use new
;                                   fully-registered label maps
;                                   generated by
;                                   process_glimpse_irdc.pro
;       Modified: 07/02/12, TPEB -- Added constricting top-hat
;                                   function to impose on the label
;                                   map to limit spatial extent of
;                                   morphological matching region.
;       Modified: 07/04/12, TPEB -- Updated header documentation.
;       Modified: 08/03/12, TPEB -- Added ALPHA option for finding
;                                   best way to turn chisq into a
;                                   DPDF, and added memory-cleaning
;                                   lines.
;       Modified: 08/20/12, TPEB -- Moved OMNI_EMAF_MORPH_FFORE to a new
;                                   routine FFORE_LBD.pro.
;       Modified: 09/05/12, TPEB -- Added IRAC BAND4 aperture
;                                   correction factor of 0.737 to
;                                   account for scattering of light
;                                   within the camera.
;       Modified: 09/06/12, TPEB -- Fixed the scattered light aperture
;                                   correction added yesterday.
;       Modified: 09/27/12, TPEB -- Shifted FFORE calculation from the
;                                   analytical calculation to using
;                                   the FFORE data cube (l,b,d).
;       Modified: 10/19/12, TPEB -- Moved the IRAC Band 4 scattering
;                                   term correction to
;                                   process_glimpse_irdo.pro so that
;                                   the postage-stamp images are
;                                   correct for all purposes.
;       Modified: 11/02/12, TPEB -- Added forcing ffore <= 1.0.
;       Modified: 11/26/12, TPEB -- Changed default alpha to 3.
;       Modified: 11/27/12, TPEB -- Changes to PostScript plots, plus
;                                   going back to alpha = 2.
;       Modified: 12/13/12, TPEB -- Adjusted the location of the
;                                   colorbars to make them line up
;                                   with the plot windows.
;       Modified: 01/14/13, TPEB -- Adding functionality for alternate
;                                   DPDF formulation, suggested by
;                                   Erik.  Also, code cleanup to
;                                   remove old testing sections.
;       Modified: 01/17/13, TPEB -- Added optional output for
;                                   alternate DPDF formulation (PROB).
;       Modified: 02/07/13, TPEB -- Made EPS plots paper-friendly.
;       Modified: 03/01/13, TPEB -- Name change from IRDC -> EMAF to
;                                   reflect the paper referenced
;                                   above.  In the shift to OMNI_*.pro
;                                   code and generalized configuration
;                                   file input: name change and made
;                                   compatible with the new
;                                   framework.  Some (many?) of the
;                                   debugging options from
;                                   irdc_morph.pro have been removed.
;       Modified: 03/13/13, TPEB -- Cleaning out old commented-out
;                                   code sections, and fixed bug with
;                                   MAKE_PS section.
;       Modified: 03/14/13, TPEB -- Default returned prob vector is
;                                   now uniform, non-zero DPDF with
;                                   unit integral probability.
;       Modified: 03/20/13, TPEB -- Added CONFFILE optional input for
;                                   conformity with other routines.
;       Modified: 05/08/14, TPEB -- Add LOCAL.OUTPUT element to point
;                                   to the actual output directory.
;
;-

FUNCTION OMNI_EMAF_MORPH, s, dvec, MAKE_PS=make_ps, VERBOSE=verbose, $
                          TOPHAT=tophat, TD=Td, SUFF=suff, $
                          ALPHA=alpha, UPSILON=upsilon, SILENT=silent, $
                          DIFF=diff, DOF=dof, CONFFILE=cfile
  
  COMPILE_OPT IDL2, LOGICAL_PREDICATE
  
  COMMON OMNI_CONFIG, conf, mw, local, dpdfs, ancil, fmt, conffile
  COMMON POSTAGE_BLOCK, common_img, common_hdr
  COMMON CUBE_BLOCK, ff_cube, ff_astr, ff_dist
  
  ;; If the FFORE data cube (l,b,d) is not loaded into the COMMON
  ;;   block, do so now.  This step should be included in
  ;;   distance-omnibus.pro upon detection of dpdfs.dpdf.emaf=1b.
  IF total(size(ff_cube)) EQ 0 THEN omni_load_ffore
  
  
  start_t = systime(1)
  ;; Parse keywords
  verbose = KEYWORD_SET(verbose)
  silent  = KEYWORD_SET(silent)
  IF n_elements(suff)  EQ 0 THEN suff=''
  IF n_elements(alpha) EQ 0 THEN alpha=2.
  
  ;; Read in survey-info, galactic-params, & dpdf-params config files
  conf = omni_load_conf(cfile)
  IF ~exist(mw) THEN mw = omni_read_conffile('./conffiles/galactic_params.conf')
  IF ~exist(dpdfs) THEN $
     dpdfs = omni_read_conffile('./conffiles/dpdf_params.conf')
  IF n_elements(dvec) NE 0 THEN  d = dvec  ELSE $
     d = dindgen(dpdfs.nbins)*dpdfs.binsize + dpdfs.binstart
  IF n_elements(Td) EQ 0 THEN Td = mw.Td
  
  
  ;; Set directory names and whatnot
  EMAF_DIR = local.emafpost
  scnum = string(s.cnum,format=fmt)
  sfwhm = string(conf.fwhm,format="(I0)") ; String for filenames
  
  ;; Define arrays
  prob = dblarr(n_elements(d)) + 1.d/(n_elements(d))
  diff = dblarr(n_elements(d))
  
  IF verbose && ~silent THEN $
     message,'Running OMNI_EMAF_MORPH on BGPS #'+string(s.cnum,format=fmt),/inf
  
  
  ;; Check that this object has the processed GLIMPSE / EMAF postage
  ;;   stamps.
  IF ~FILE_TEST(EMAF_DIR+conf.survey+'_mapdat'+scnum+'.fits',/READ) THEN BEGIN
     message,'Source not contained in EMAFPOST location...',/inf
     return,prob
  ENDIF
  
  
  ;; Read in the proper files for this object
  IF n_elements(common_img) EQ 0 THEN BEGIN
     map = readfits(EMAF_DIR+conf.survey+'_mapdat'+scnum+suff+'.fits',maphdr, $
                    /silent) * conf.fluxcor
     Imir = readfits(EMAF_DIR+conf.survey+'_Imir'+scnum+suff+'.fits',imirhdr, $
                     /silent)
     irac = readfits(EMAF_DIR+conf.survey+'_s'+sfwhm+'arc'+scnum+suff+'.fits',$
                     irachdr, /silent)
     IF conf.haslabel THEN $
        labl = readfits(EMAF_DIR+conf.survey+'_label'+scnum+suff+'.fits',$
                        labhdr, /silent) $
     ELSE BEGIN
        message,'Warning: '+conf.survey+' does not have label maps.  '+$
                'PROB_EMAF cannot be computed!',/cont
        RETURN,prob
     ENDELSE
  ENDIF ELSE BEGIN  ;; READ IN FROM COMMON BLOCK
     ;; message,'Running from COMMON...',/inf
     sind = WHERE(common_img.cnum EQ s.cnum, ns)
     IF ns NE 1 THEN message,'500 CCs of vodka, STAT!'
     map = common_img[sind].map
     Imir = common_img[sind].imir
     irac = common_img[sind].irac
     labl = common_img[sind].labl
     maphdr = common_hdr[sind].map
     imirhdr = common_hdr[sind].imir
     irachdr = common_hdr[sind].irac
     labhdr  = common_hdr[sind].labl
  ENDELSE
  label = labl                  ; To keep track for pixel removal
  
  l = s.glon
  b = s.glat
  
  
  time1 = systime(1) - start_t
  ;;========================================================
  ;; Determine hits pixels
  labl *= (irac LE Imir)        ; Only compare extincted pixels
  
  hits = where(labl, pixct)
  
  ;; If pixct=0, then no overlap, return uniform DPDF
  IF pixct EQ 0 THEN BEGIN
     message,'Warning: Object #'+string(s.cnum,format=fmt)+' has no '+$
             'valid pixels.  PROB_EMAF cannot be computed!',/cont
     RETURN,prob  
  ENDIF
  ;; Degrees of freedom, given that pixels are not independent.
  dof = double(pixct) / 23.8d
  
  ;;=================================================================
  ;; Calculate the optical depth map based on MAP & Td
  IF n_elements( upsilon ) EQ 0 THEN upsilon = omni_flux2tau_emaf( Td )
  
  taumap = upsilon * (map > 0.d)
  
  ;; Get statistics and the ffore from the model along the LoS
  maprms = mad(map)
  modelrms = Imir * exp(-taumap) * upsilon * maprms * (1.d)
  
  ;; Work the FFORE MAGIC!
  dfvec = dindgen(dpdfs.NBINS*5.)*dpdfs.BINSIZE + dpdfs.BINSTART
  ad2xy,s.glon,s.glat,ff_astr,xi,yi
  ff = (ff_cube[xi,yi,*]) < 1.0
  ffore = interpol(ff,ff_dist,dfvec) < 1.0
  
  ;; Loop over distances!
  FOR j=0L, n_elements(d)-1 DO BEGIN
     
     ;; Model 8-um emission
     undefine,model
     model = Imir * ( ffore[j] + (1.d - ffore[j]) * exp(-taumap) )
     
     ;; \chi^2_j
     ;; Divide by number of pixels per beam!!!
     diff[j] = TOTAL(((irac-model)[hits])^2 / modelrms[hits]^2 / 23.8d)
     
  ENDFOR
  
  ;; DPDF & Calculate statistics (namely degrees of freedom given
  ;;    pixels are not independent)
  invchsq = diff^(-float(alpha))
  invchsq /= MAX(invchsq)
  dof = (floor(n_elements(hits)/conf.ppbeam)-1) > 1
  min_diff = min(diff,j)
  
  time2 = systime(1) - start_t
  ;;================================================================
  ;; If selected, generate pretty pictures
  IF KEYWORD_SET( make_ps ) THEN BEGIN
     
     COMMON VEL_BLOCK, v, v_std
     IF ~ exist(v) THEN BEGIN
        message,'Warning: COMMON VEL_BLOCK required '+$
                'for KDIST overlay',/cont
        kprob = (invchsq*0.d + 1.d)
        do_overlay = 0b
     ENDIF ELSE BEGIN
        this  = WHERE(v.cnum EQ s.cnum, nind)
        v_spec = omni_vspec( [1.,v[this].vlsr,v[this].lw], v_std )
        kprob = omni_kdist_spectrum(s.glon, s.glat, v_std, v_spec, $
                                    DVEC=dvec, CONSTRAIN=constrain)
        kprob /= MAX(kprob)
        do_overlay = 1b
     ENDELSE
     
     ;; The model for the best-fit distance
     model = Imir * ( ffore[j] + (1.d - ffore[j]) * exp(-taumap) )
     
     ;; Clip irac image intensities for plotting purposes
     thresh = ( MEDIAN(Imir) + 1.d*MAD(irac) )
     irac = irac < thresh
     pr = set_plot_range(irac)
     
     ;; Set plot environment
     myps,local.output+conf.survey+'_morph'+scnum+'.eps',$
          xsize=6.5,ysize=5.65,ct=0,/cmyk
     charsize = 0.7
     chi = cgSymbol('chi')
     sun = cgSymbol('sun')
     legcolor1 = 'WT3'
     legcolor2 = 'Black'
     
     multiplot,[2,2],ygap=0.02,xgap=0.042
     
     cgText,/norm,align=0.5,0.5,0.97,'MAP #'+string(s.cnum,format=fmt),$
            charsize=charsize*1.2
     
     
     ;;=======================================
     ;; Panel 1 -- Model 8-um plot
     plotmap,model,irachdr,charsize=charsize,range=pr,XC=xc,YC=yc,ct=0
     cgContour,labl,xc,yc,levels=[0.5],thick=5,/overplot,$
               color='Crimson',label=0
     al_legend,/top,/right,['(a)'],textcolor=legcolor2,charsize=charsize*1.2,$
               box=0
     al_legend,/bottom,/left,['Synthetic'],textcolor=legcolor2,$
               charsize=charsize*1.1,box=0
     
     multiplot,/doyaxis,/doxaxis
     
     ;;=======================================
     ;; Panel 2 -- MAP image
     plotmap,map>0.d,maphdr,charsize=charsize,ct=3,range=bpr,$
             axcolor='WT3'
     cgContour,labl,xc,yc,levels=[0.5],thick=5,/overplot,$
               color='light cyan',label=0
     al_legend,/top,/right,['(b)'],textcolor=legcolor1,charsize=charsize*1.2,$
               box=0
     al_legend,/bottom,/left,['MAP'],textcolor=legcolor1,$
               charsize=charsize*1.1,box=0
     bywin = !y.window
     bxwin = !x.window
     
     multiplot,/doxaxis,/doyaxis
    
     ;;=======================================
     ;; Panel 3 -- Smoothed GLIMPSE image
     plotmap,irac,irachdr,charsize=charsize,range=pr,ct=0
     cgContour,labl,xc,yc,levels=[0.5],thick=5,/overplot,$
               color='Crimson',label=0
     al_legend,/top,/right,['(c)'],textcolor=legcolor2,charsize=charsize*1.2,$
               box=0
     gywin = !y.window
     al_legend,/bottom,/left,['GLIMPSE'],textcolor=legcolor2,$
               charsize=charsize*1.1,box=0
     
     multiplot,/doxaxis,/doyaxis
     
     ;;=======================================
     ;; Panel 4 -- CHISQ plot
     cgPlot, d/1.d3, invchsq, xtit='Heliocentric Distance  [kpc]',yr=[0,1.05],$
             /yst,/nodata,ytit='Relative Probability',ytickformat="(F0.1)",$
             charsize=charsize,position=[bxwin[0],gywin[0],bxwin[1],gywin[1]]
     
     ;; Plot D_tan & ffore(d)
     tandist = mw.R0*cos(l * !dtor)/1.d3
     cgOplot,d/1.d3,ffore,color='BLK6',linestyle=1,thick=3
     vline,tandist,color='Green',thick=6
     cgText,tandist+0.2,0.98,['d!dtan!n'],charsize=charsize,color='Green'
     
     ;; Molecular gas prior
     h2_prob = prob_h2(s)
     h2_prob /= max(h2_prob)
     cgOplot,d/1.d3,h2_prob,thick=3,color='BLU5',linestyle=3
     
     ;; Plot Morph Match DPDF
     cgOplot,d/1.d3, invchsq,thick=6
     
     IF do_overlay THEN BEGIN
        totprob = (kprob * invchsq * h2_prob) / MAX(kprob * invchsq * h2_prob)
        cgOplot,d/1.d3, totprob, thick=6, color=probcolor(2)
     ENDIF
     
     axis,xaxis=0,xthick=3,/xst,xtickformat='blank_axis'
     al_legend,/top,/right,['(d)'],textcolor=legcolor2,charsize=charsize*1.2,$
               box=0
     
     cgLoadct,0,/silent
     cgcolorbar,range=pr,position=[0.905,gywin[0],0.925,gywin[1]],$
                divisions=0,title='GLIMPSE Intensity  [MJy sr!u-1!n]',$
                charsize=charsize,/vertical,/right
     
     cgLoadct,3,/silent
     cgcolorbar,range=bpr,position=[0.905,bywin[0],0.925,bywin[1]],$
                divisions=0,title='MAP Flux Density  [Jy beam!u-1!n]',$
                charsize=charsize,/vertical,/right
     myps,/done,/mp
     
  ENDIF  ;; End of postscript-creating IF block
  
  ;; Clean Memory
  undefine,map,Imir,irac,label,labl
  
  time3 = systime(1) - start_t
  ;; print,time1,time2,time3
  
  junk = CHECK_MATH()
  RETURN,invchsq  ;; Return the inverse chi-squared function as the prior PDF
END
