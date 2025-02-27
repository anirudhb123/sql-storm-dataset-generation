WITH RankedActors AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        nt.kind AS name_type,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.nr_order) AS actor_rank
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
    JOIN 
        role_type nt ON a.role_id = nt.id
),

FilmDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        STRING_AGG(CONCAT(cn.name, ' (', ct.kind, ')'), ', ' ORDER BY cn.name) AS companies
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.id, t.title, t.production_year
),

ActorMovieCount AS (
    SELECT 
        r.actor_name,
        COUNT(DISTINCT f.movie_id) AS movie_count,
        MAX(f.production_year) AS last_movie_year
    FROM 
        RankedActors r
    LEFT JOIN 
        complete_cast c ON r.person_id = c.subject_id
    LEFT JOIN 
        FilmDetails f ON c.movie_id = f.movie_id
    GROUP BY 
        r.actor_name
),

FilteredMovies AS (
    SELECT 
        f.*,
        CASE 
            WHEN amc.movie_count IS NULL THEN 'New Actor'
            ELSE 'Established Actor'
        END AS actor_status
    FROM 
        FilmDetails f
    LEFT JOIN 
        ActorMovieCount amc ON f.title LIKE '%' || amc.actor_name || '%'
    WHERE 
        f.production_year > 2000
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keyword,
    fm.companies,
    fm.actor_status,
    COALESCE(amc.actor_name, 'Unknown Actor') AS featured_actor,
    CASE 
        WHEN fm.keyword = 'Action' THEN 'Blockbuster'
        ELSE 'Indie'
    END AS movie_type,
    COUNT(DISTINCT fm.movie_id) OVER (PARTITION BY fm.keyword) AS keyword_movie_count,
    MAX(fm.production_year) OVER (PARTITION BY fm.keyword) AS latest_year_by_keyword
FROM 
    FilteredMovies fm
LEFT JOIN 
    RankedActors ra ON fm.title ILIKE '%' || ra.actor_name || '%'
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;
