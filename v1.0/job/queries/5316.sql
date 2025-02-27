
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id ASC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        mw.movie_id,
        COUNT(kw.keyword) AS keyword_count
    FROM 
        movie_keyword mw
    JOIN 
        keyword kw ON mw.keyword_id = kw.id
    JOIN 
        movie_info mi ON mw.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        mw.movie_id
    HAVING 
        COUNT(kw.keyword) > 10
),
CompleteCastDetails AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT a.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        cc.movie_id
),
FinalResults AS (
    SELECT 
        r.title,
        r.production_year,
        tcm.actor_count,
        tcm.actor_names,
        tt.keyword_count
    FROM 
        RankedTitles r
    JOIN 
        CompleteCastDetails tcm ON r.title_id = tcm.movie_id
    JOIN 
        TopRatedMovies tt ON r.title_id = tt.movie_id
    WHERE 
        r.year_rank <= 3
)
SELECT 
    title,
    production_year,
    actor_count,
    actor_names,
    keyword_count
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    title ASC;
