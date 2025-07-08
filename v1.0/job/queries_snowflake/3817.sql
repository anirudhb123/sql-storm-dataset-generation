WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        COALESCE(ki.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        rm.rank_by_cast_count <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ki.keyword
)
SELECT 
    f.title,
    f.production_year,
    f.keyword,
    f.total_cast,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = f.movie_id)) AS unique_actors
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.total_cast DESC;
