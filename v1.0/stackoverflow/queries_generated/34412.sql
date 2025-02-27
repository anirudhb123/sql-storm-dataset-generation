WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 50
    GROUP BY 
        u.Id, u.DisplayName
),
MostCommentedPosts AS (
    SELECT 
        PostID,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        CommentCount > 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    rp.UpVotes,
    rp.DownVotes,
    tu.DisplayName AS OwnerDisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    COALESCE(ph.LastClosedDate, 'Not Closed') AS LastClosedDate,
    COALESCE(ph.LastReopenedDate, 'Not Reopened') AS LastReopenedDate,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top'
        WHEN rp.Rank <= 5 THEN 'Top 5'
        ELSE 'Others' 
    END AS PostRank
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostID = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    TopUsers tu ON u.Id = tu.UserID
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId
WHERE 
    (rp.UpVotes - rp.DownVotes) >= 10 
    AND rp.Rank <= 5
    OR p.Id IN (SELECT PostID FROM MostCommentedPosts)
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
