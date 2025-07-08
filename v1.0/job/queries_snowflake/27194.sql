
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(c.person_id) > 5
),
SelectedTitles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year BETWEEN 2000 AND 2020
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    st.title AS movie_title,
    st.production_year,
    st.rank,
    mk.keywords,
    mi.info_details
FROM 
    SelectedTitles st
LEFT JOIN 
    MovieKeywords mk ON st.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON st.movie_id = mi.movie_id
ORDER BY 
    st.rank;
