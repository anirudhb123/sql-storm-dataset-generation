WITH PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Deleted User') AS Author,
        p.Tags,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = p.Id
        )
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, ph.UserDisplayName, u.DisplayName
),
CommentDetail AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentsCount,
        STRING_AGG(Text, '; ') AS Comments
    FROM 
        Comments
    GROUP BY 
        PostId
),
VoteDetail AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT UserId) AS UniqueVoters
    FROM 
        Votes V
    GROUP BY 
        PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Author,
    pd.CreationDate,
    pd.LastEditDate,
    pd.ViewCount,
    pd.Score,
    pd.LastEditor,
    cd.CommentsCount,
    cd.Comments,
    vd.UpVotes,
    vd.DownVotes,
    vd.UniqueVoters,
    pd.PostTypeNames
FROM 
    PostDetail pd
LEFT JOIN 
    CommentDetail cd ON pd.PostId = cd.PostId
LEFT JOIN 
    VoteDetail vd ON pd.PostId = vd.PostId
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
