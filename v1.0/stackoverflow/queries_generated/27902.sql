WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'))::int)
                          )
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
VoteDetails AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN vt.Name IN ('Close') THEN 1 END) AS CloseVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.ViewCount,
    pd.Score,
    COALESCE(vd.UpVotes, 0) AS UpVotes,
    COALESCE(vd.DownVotes, 0) AS DownVotes,
    COALESCE(vd.CloseVotes, 0) AS CloseVotes,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    COALESCE(cs.LastCommentDate, 'No comments') AS LastCommentDate,
    pd.Tags
FROM 
    PostDetails pd
LEFT JOIN 
    VoteDetails vd ON pd.PostId = vd.PostId
LEFT JOIN 
    CommentStats cs ON pd.PostId = cs.PostId
ORDER BY 
    pd.ViewCount DESC, 
    pd.Score DESC
LIMIT 10;
