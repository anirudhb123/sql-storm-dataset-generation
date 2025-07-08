
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (
            SELECT 
                id 
            FROM 
                kind_type 
            WHERE 
                kind = 'Movie'
        )
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 10
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Plot' THEN mi.info END) AS plot_info,
        MAX(CASE WHEN it.info = 'Year' THEN mi.info END) AS year_info,
        COUNT(mi.id) AS total_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.plot_info, 'No plot information') AS plot_information,
    mi.total_info
FROM 
    TopMovies tm
LEFT JOIN 
    TitleKeywords tk ON tm.title_id = tk.movie_id
LEFT JOIN 
    MovieInfo mi ON tm.title_id = mi.movie_id
WHERE 
    (tm.production_year BETWEEN 2000 AND 2023 OR mi.total_info > 0) 
    AND (tk.keywords IS NOT NULL OR mi.plot_info IS NOT NULL)
ORDER BY 
    tm.production_year DESC,
    tm.title;
