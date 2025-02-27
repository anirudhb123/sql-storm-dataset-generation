WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year') 
        AND p.Score IS NOT NULL
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
MostVotedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        uv.UpVotes,
        uv.DownVotes,
        CASE 
            WHEN uv.UpVotes - uv.DownVotes > 0 THEN 'Popular' 
            ELSE 'Not Popular' 
        END AS PopularityStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVotes uv ON rp.Id = uv.PostId
    WHERE 
        rp.PostRank = 1
),
PostDetails AS (
    SELECT 
        mp.Id,
        mp.Title,
        mp.PopularityStatus,
        u.DisplayName AS OwnerName,
        COALESCE(ph.EditCount, 0) AS EditCount,
        COALESCE(ph.CloseCount, 0) AS CloseCount,
        COALESCE(ph.ReopenCount, 0) AS ReopenCount
    FROM 
        MostVotedPosts mp
    JOIN 
        Users u ON mp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN PHT.Name LIKE 'Edit%' THEN 1 END) AS EditCount,
            COUNT(CASE WHEN PHT.Name = 'Post Closed' THEN 1 END) AS CloseCount,
            COUNT(CASE WHEN PHT.Name = 'Post Reopened' THEN 1 END) AS ReopenCount
        FROM 
            PostHistory ph
        JOIN 
            PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
        GROUP BY 
            PostId
    ) ph ON mp.Id = ph.PostId
)
SELECT 
    pd.Id,
    pd.Title,
    pd.PopularityStatus,
    pd.OwnerName,
    pd.EditCount,
    pd.CloseCount,
    pd.ReopenCount,
    COALESCE(t.tag_list, 'No Tags') AS Tags
FROM 
    PostDetails pd
LEFT JOIN LATERAL (
    SELECT 
        STRING_AGG(TRIM(tag), ', ') AS tag_list
    FROM 
        unnest(string_to_array(pd.Tags, '>')) tag
) t ON true
WHERE 
    pd.EditCount > 0
ORDER BY 
    pd.Score DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;

This query performs an elaborate selection from the StackOverflow-like schema, employing several advanced SQL techniques, such as common table expressions (CTEs), window functions, lateral joins, string aggregation, and conditional aggregation. It retrieves details about users' most recent posts from the last year, their popularity based on vote counts, and additional metrics regarding post editing and closure history. The query ensures to pull relevant tags while managing potential null values effectively throughout the operations.
