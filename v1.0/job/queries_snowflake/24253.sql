
WITH RecursiveActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info cc ON ak.person_id = cc.person_id
    GROUP BY 
        ak.id, ak.person_id, ak.name
),
MoviesWithKeyword AS (
    SELECT 
        mt.movie_id,
        mt.title,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mw ON mt.movie_id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        mt.movie_id, mt.title
),
RankedMovies AS (
    SELECT 
        m.actor_id,
        mw.movie_id,
        mw.title,
        mw.keywords,
        RANK() OVER (PARTITION BY m.actor_id ORDER BY COUNT(mw.movie_id) DESC) AS movie_rank
    FROM 
        RecursiveActors m
    JOIN 
        cast_info ci ON m.person_id = ci.person_id
    JOIN 
        MoviesWithKeyword mw ON ci.movie_id = mw.movie_id
    GROUP BY 
        m.actor_id, mw.movie_id, mw.title, mw.keywords
    HAVING 
        COUNT(mw.keywords) > 1
),
FilteredMovies AS (
    SELECT 
        rm.actor_id,
        rm.movie_id,
        rm.title,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.movie_rank <= 3
        AND EXISTS (
            SELECT 1 
            FROM TABLE(FLATTEN(input => rm.keywords)) AS kw 
            WHERE kw.value IS NOT NULL AND LOWER(kw.value) LIKE '%action%'
        )
)
SELECT 
    fa.actor_id,
    fa.actor_name,
    fm.title,
    fm.keywords,
    COALESCE(fm.keywords[0], 'No Keywords') AS first_keyword,
    COUNT(DISTINCT fm.movie_id) AS total_movies,
    SUM(CASE WHEN fm.keywords IS NULL THEN 1 ELSE 0 END) AS null_keyword_count
FROM 
    RecursiveActors fa
LEFT JOIN 
    FilteredMovies fm ON fa.actor_id = fm.actor_id
GROUP BY 
    fa.actor_id, fa.actor_name, fm.title, fm.keywords
ORDER BY 
    fa.actor_name ASC,
    total_movies DESC;
