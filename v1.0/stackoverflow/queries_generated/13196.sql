-- Performance Benchmarking Query
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount,
        SUM(vt.VoteTypeId = 2) AS UpVotes,
        SUM(vt.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    GROUP BY 
        p.Id, u.Reputation, pt.Name
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerReputation,
    pd.PostTypeName,
    COALESCE(phd.EditCount, 0) AS EditCount,
    phd.LastEditDate,
    pd.UpVotes,
    pd.DownVotes
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistoryDetails phd ON pd.PostId = phd.PostId
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
