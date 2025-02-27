WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        SUM(b.Class = 1) AS GoldBadgeCount,
        SUM(b.Class = 2) AS SilverBadgeCount,
        SUM(b.Class = 3) AS BronzeBadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pl.PostId AS RelatedPostId,
        CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment
            ELSE 'No reason provided'
        END AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostLinks pl ON ph.PostId = pl.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
        AND ph.CreationDate >= NOW() - INTERVAL '6 MONTH'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
FinalRankedPosts AS (
    SELECT 
        rp.*, 
        COALESCE(ue.TotalPosts, 0) AS UserTotalPosts,
        COALESCE(ue.TotalUpVotes, 0) AS UserTotalUpVotes,
        COALESCE(ue.TotalDownVotes, 0) AS UserTotalDownVotes,
        COALESCE(ue.AverageScore, 0) AS UserAverageScore,
        CASE 
            WHEN cp.CloseReason IS NOT NULL THEN 'Closed: ' || cp.CloseReason
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserEngagement ue ON rp.OwnerUserId = ue.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    Rank,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    UserTotalPosts,
    UserTotalUpVotes,
    UserTotalDownVotes,
    UserAverageScore,
    PostStatus
FROM 
    FinalRankedPosts
WHERE 
    (PostStatus LIKE 'Closed%' OR UserAverageScore > (SELECT AVG(AverageScore) FROM UserEngagement))
ORDER BY 
    Rank ASC, Score DESC
LIMIT 100;
