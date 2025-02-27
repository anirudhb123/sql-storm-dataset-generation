WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.Score > 0 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
), RecentUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= '2023-01-01'
    GROUP BY 
        u.Id, u.DisplayName
), QuestionCloseReason AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INT) 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close or Reopen actions
    GROUP BY 
        ph.PostId
) 
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    rh.PostRank,
    rus.DisplayName AS UserName,
    rus.PostsCreated,
    rus.GoldBadges,
    rus.SilverBadges,
    rus.BronzeBadges,
    COALESCE(cr.CloseReasons, 'No Close Reason') AS CloseReasonDetails
FROM 
    RankedPosts rp
JOIN 
    RecentUserStats rus ON rp.PostId IN (SELECT AnsweredPostId FROM Posts WHERE AcceptedAnswerId = rp.PostId)
LEFT JOIN 
    QuestionCloseReason cr ON cr.PostId = rp.PostId
WHERE 
    rp.PostRank = 1 -- Top-ranked post by type
ORDER BY 
    rp.Score DESC, 
    rp.Upvotes DESC;
