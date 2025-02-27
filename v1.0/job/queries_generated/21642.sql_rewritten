WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(mk.keyword_count, 0) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
CombinedData AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        am.actor_name,
        ROW_NUMBER() OVER (PARTITION BY tm.movie_id ORDER BY am.actor_name) AS actor_rank
    FROM 
        TopMovies tm
    LEFT JOIN ActorMovies am ON tm.movie_id = am.movie_id
),
FinalResults AS (
    SELECT 
        cd.movie_id,
        cd.title,
        cd.production_year,
        STRING_AGG(cd.actor_name, ', ') AS actor_list
    FROM 
        CombinedData cd
    WHERE 
        cd.actor_name IS NOT NULL
    GROUP BY 
        cd.movie_id, cd.title, cd.production_year
),
KeywordSummary AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_list,
    COALESCE(ks.keywords, 'No keywords') AS keywords
FROM 
    FinalResults fr
LEFT JOIN 
    KeywordSummary ks ON fr.movie_id = ks.movie_id
ORDER BY 
    fr.production_year DESC, fr.title;