WITH RECURSIVE SuccessfulMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 2
),
FilteredMovies AS (
    SELECT 
        sm.movie_id,
        sm.title,
        sm.production_year,
        sm.actor_count,
        k.keyword
    FROM 
        SuccessfulMovies sm
    LEFT JOIN 
        TopKeywords k ON sm.movie_id = k.movie_id
),
DetailedInfo AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.actor_count,
        COALESCE(f.keyword, 'No Keywords') AS keyword,
        ARRAY_AGG(DISTINCT p.info) AS additional_info
    FROM 
        FilteredMovies f
    JOIN 
        movie_info mi ON f.movie_id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        person_info p ON mi.movie_id = p.person_id
    WHERE 
        it.info ILIKE '%Award%'
    GROUP BY 
        f.movie_id, f.title, f.production_year, f.actor_count, f.keyword
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        keyword,
        additional_info,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank_order
    FROM 
        DetailedInfo
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.keyword,
    rm.additional_info,
    rm.rank_order
FROM 
    RankedMovies rm
WHERE 
    rm.rank_order <= 10
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
