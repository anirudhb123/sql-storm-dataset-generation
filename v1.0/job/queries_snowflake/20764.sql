
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(c.person_id) DESC) AS actor_rank,
        t.id AS movie_id
    FROM 
        aka_title AS t
        JOIN cast_info AS c ON t.id = c.movie_id
        JOIN aka_name AS ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year, ak.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY mk.id DESC) AS keyword_rank
    FROM 
        movie_keyword AS mk
        JOIN keyword AS k ON mk.keyword_id = k.id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_name,
        mq.keyword
    FROM 
        RankedMovies AS rm
        LEFT JOIN MovieKeywords AS mq ON rm.movie_id = mq.movie_id
    WHERE 
        rm.actor_rank <= 3 AND
        (mq.keyword IS NULL OR mq.keyword LIKE '%thriller%')
),
DistinctYears AS (
    SELECT DISTINCT
        production_year
    FROM
        FilteredMovies
)
SELECT
    fm.title,
    fm.production_year,
    fm.actor_name,
    COUNT(DISTINCT fm.keyword) AS keyword_count,
    COALESCE(DENSE_RANK() OVER (ORDER BY fm.production_year), 0) AS year_rank,
    CASE 
        WHEN EXISTS (SELECT 1 FROM info_type WHERE info = 'Box Office') THEN 'Box Office Info Available'
        ELSE 'No Box Office Info'
    END AS box_office_info,
    (SELECT AVG(production_year) FROM aka_title WHERE production_year IS NOT NULL) AS average_production_year
FROM 
    FilteredMovies AS fm
GROUP BY 
    fm.title, fm.production_year, fm.actor_name
ORDER BY 
    fm.production_year DESC, keyword_count DESC;
