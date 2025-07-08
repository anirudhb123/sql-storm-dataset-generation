
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY b.imdb_index DESC) AS rank_per_year
    FROM 
        aka_title a
    JOIN 
        aka_name b ON a.id = b.id
    WHERE 
        a.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        cast_info c
    LEFT JOIN 
        name n ON c.person_id = n.imdb_id
    GROUP BY 
        c.movie_id
),
MoviesWithInfo AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        m.total_cast_members,
        m.cast_names,
        m.null_notes_count,
        COALESCE(i.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies r
    LEFT JOIN 
        MovieCast m ON r.movie_id = m.movie_id
    LEFT JOIN 
        movie_info i ON r.movie_id = i.movie_id AND i.info_type_id IN (
            SELECT id FROM info_type WHERE info LIKE 'B%')
)
SELECT 
    mw.title,
    mw.production_year,
    mw.total_cast_members,
    mw.null_notes_count,
    mw.additional_info,
    CASE 
        WHEN mw.total_cast_members IS NULL THEN 'Empty Cast List'
        ELSE 'Cast Available'
    END AS cast_status,
    DENSE_RANK() OVER (ORDER BY mw.production_year DESC) AS year_rank,
    CASE 
        WHEN mw.null_notes_count > 0 THEN 'Contains NULL Notes'
        ELSE 'All Notes Present'
    END AS note_status
FROM 
    MoviesWithInfo mw
WHERE 
    mw.additional_info NOT LIKE 'No%'
ORDER BY 
    mw.production_year DESC, mw.title;
