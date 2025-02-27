
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    ps.PostId,
    ps.CreationDate,
    ps.PostTypeId,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerReputation,
    ISNULL(phs.EditCount, 0) AS EditCount,
    phs.LastEditDate,
    ISNULL(vs.UpVotes, 0) AS UpVotes,
    ISNULL(vs.DownVotes, 0) AS DownVotes,
    ISNULL(vs.TotalVotes, 0) AS TotalVotes
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
LEFT JOIN 
    VoteStats vs ON ps.PostId = vs.PostId
ORDER BY 
    ps.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
