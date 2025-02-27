WITH RecursiveActorMovies AS (
    SELECT 
        c.person_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        cast_info AS c
    JOIN 
        aka_title AS t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        person_id, 
        COUNT(*) AS movie_count
    FROM 
        RecursiveActorMovies
    GROUP BY 
        person_id
),
TopActors AS (
    SELECT 
        a.id,
        a.name,
        amc.movie_count
    FROM 
        aka_name AS a
    JOIN 
        ActorMovieCount AS amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
),
MoviesWithInfo AS (
    SELECT 
        t.movie_id,
        t.title,
        COALESCE(mi.info, 'No info available') AS movie_info,
        CASE 
            WHEN mi.note IS NULL THEN 'Note not provided'
            ELSE mi.note
        END AS note
    FROM 
        MoviesWithKeywords AS t
    LEFT JOIN 
        movie_info AS mi ON t.movie_id = mi.movie_id
),
FinalResults AS (
    SELECT 
        a.name, 
        mw.title, 
        mw.movie_info,
        mw.keywords,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mw.title) AS actor_movie_rank
    FROM 
        TopActors AS a
    JOIN 
        MoviesWithInfo AS mw ON a.id = mw.movie_id
    WHERE 
        mw.title LIKE '%The%' AND
        (mw.movie_info IS NOT NULL OR mw.keywords IS NOT NULL)
    ORDER BY 
        a.name
)
SELECT 
    f.name AS Actor_Name,
    f.title AS Movie_Title,
    f.movie_info AS Movie_Info,
    f.keywords AS Movie_Keywords,
    CASE 
        WHEN f.actor_movie_rank IS NULL THEN 'Rank not assigned'
        ELSE f.actor_movie_rank::text
    END AS Movie_Rank
FROM 
    FinalResults AS f
WHERE 
    f.Movie_Rank IS NOT NULL
ORDER BY 
    Actor_Name, Movie_Title;
