WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= NOW() - INTERVAL '365 days'
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(v.Id) > 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS RevisionCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPostsWithHistory AS (
    SELECT 
        rp.*,
        ph.RevisionCount,
        ph.LastEdited
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails ph ON rp.Id = ph.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.DisplayName AS ActiveUser,
    pp.Title,
    pp.Score,
    pp.RevisionCount,
    pp.LastEdited,
    pp.ViewCount,
    pp.AnswerCount
FROM 
    MostActiveUsers t
JOIN 
    TopPostsWithHistory pp ON t.UserId = pp.OwnerDisplayName
ORDER BY 
    t.VoteCount DESC, pp.Score DESC;
