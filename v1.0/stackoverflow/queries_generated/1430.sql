WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title,
        p.Body,
        ph.Comment,
        p.AcceptedAnswerId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    pu.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(pv.TotalBounty) AS TotalBountyCollected,
    AVG(rp.ViewCount) AS AvgViewCount,
    AVG(rp.CommentCount) AS AvgCommentCount,
    pht.Title,
    MAX(pht.HistoryDate) AS LastHistoryUpdate,
    pht.AnswerStatus
FROM 
    PopularUsers pu
LEFT JOIN 
    RankedPosts rp ON pu.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryDetails pht ON rp.PostId = pht.PostId
WHERE 
    rp.rn = 1 
GROUP BY 
    pu.DisplayName, pht.Title, pht.AnswerStatus
HAVING 
    AVG(rp.ViewCount) > 100
ORDER BY 
    TotalPosts DESC, TotalBountyCollected DESC;
