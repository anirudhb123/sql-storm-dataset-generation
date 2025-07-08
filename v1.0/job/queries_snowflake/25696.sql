WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS role_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id
    FROM 
        RankedMovies
    WHERE 
        role_rank <= 5
), 
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        tt.title,
        tt.production_year,
        tt.kind_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        TopMovies tt ON ci.movie_id = tt.movie_id
)
SELECT 
    ad.actor_name,
    tm.title,
    tm.production_year,
    kt.kind,
    COUNT(DISTINCT ci.id) AS roles_count
FROM 
    ActorDetails ad
JOIN 
    title tm ON ad.title = tm.title AND ad.production_year = tm.production_year
JOIN 
    kind_type kt ON tm.kind_id = kt.id
JOIN 
    cast_info ci ON ci.person_id = ad.person_id AND ci.movie_id = tm.id
GROUP BY 
    ad.actor_name, tm.title, tm.production_year, kt.kind
ORDER BY 
    roles_count DESC, ad.actor_name;
