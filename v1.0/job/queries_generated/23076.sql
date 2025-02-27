WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
TopRatedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(ci.person_id) AS cast_count,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
    HAVING 
        COUNT(ci.person_id) > 3
), 
MoviesWithImdbData AS (
    SELECT 
        tt.movie_id,
        tt.title,
        tt.production_year,
        tt.cast_count,
        tt.era,
        ak.name AS main_actor,
        ak.surname_pcode
    FROM 
        TopRatedMovies tt
    LEFT JOIN 
        cast_info ci ON tt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.md5sum IS NOT NULL 
        AND ak.name NOT LIKE '%Unknown%'
        AND ak.name NOT LIKE '%unnamed%'
)

SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.cast_count,
    mw.era,
    mw.main_actor,
    mw.surname_pcode,
    COALESCE((SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mw.movie_id), 0) AS keyword_count,
    (SELECT STRING_AGG(k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = mw.movie_id) AS keywords,
    (SELECT MAX(mr.linked_movie_id) 
     FROM movie_link mr 
     WHERE mr.movie_id = mw.movie_id) AS last_linked_movie,
    CASE WHEN (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mw.movie_id) > 5 
        THEN 'Has extensive info' 
        ELSE 'Limited info' 
    END AS info_status
FROM 
    MoviesWithImdbData mw
ORDER BY 
    mw.production_year DESC, 
    mw.cast_count DESC;
