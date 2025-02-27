WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ca.person_id, 
        ca.movie_id, 
        r.role AS role_name, 
        COUNT(ca.id) AS role_count
    FROM 
        cast_info ca
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        ca.person_id, ca.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.movie_id,
        a.role_name,
        RANK() OVER (PARTITION BY a.person_id ORDER BY a.role_count DESC) AS rank
    FROM 
        ActorRoles a
)
SELECT 
    DISTINCT m.title, 
    m.production_year, 
    ak.name AS actor_name, 
    ak.surname_pcode,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tr.movie_id IS NOT NULL THEN 'Top Ranked'
        ELSE 'Regular'
    END AS movie_rank_status
FROM 
    RankedMovies m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    MovieKeywords kw ON m.movie_id = kw.movie_id
LEFT JOIN 
    TopActors tr ON ak.person_id = tr.person_id AND tr.rank = 1
WHERE 
    m.year_rank <= 5 
    AND (m.production_year IS NOT NULL OR m.production_year IS NOT NULL)
ORDER BY 
    m.production_year DESC, 
    movie_rank_status, 
    ak.name;
