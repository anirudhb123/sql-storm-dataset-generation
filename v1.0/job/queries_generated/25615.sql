WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) as rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
), ActorDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
), MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'Tagline' THEN mi.info END, '; ') AS taglines,
        STRING_AGG(CASE WHEN it.info = 'Summary' THEN mi.info END, '; ') AS summaries
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    ad.actor_name,
    ad.actor_role,
    ad.role_count,
    mcd.company_name,
    mcd.company_type,
    mid.taglines,
    mid.summaries
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
LEFT JOIN 
    MovieInfoDetails mid ON rm.movie_id = mid.movie_id
WHERE 
    ad.role_count > 1
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
