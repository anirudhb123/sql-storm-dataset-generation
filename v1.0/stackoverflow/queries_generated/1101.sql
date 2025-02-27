WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS UserPostRank
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        p.Id, u.Id
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id
),
PostScoreSummary AS (
    SELECT
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    ua.TotalBounties,
    ua.TotalPosts,
    ps.Upvotes,
    ps.Downvotes,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score > 10 THEN 'High Score'
        ELSE 'Regular Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN UserActivity ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN PostScoreSummary ps ON rp.Id = ps.PostId
WHERE 
    rp.UserPostRank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
