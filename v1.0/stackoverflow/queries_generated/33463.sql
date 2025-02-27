WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(COUNT(p.Id), 0) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name = 'Post Closed'
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.TotalScore,
    ups.PostCount,
    SUM(rp.Score) FILTER (WHERE rp.UserRank <= 5) AS TopUserPostsScore,
    COUNT(DISTINCT rph.PostId) AS ClosedPostsCount,
    STRING_AGG(DISTINCT rph.UserDisplayName || ': ' || rph.Comment, '; ') AS ClosedPostComments
FROM 
    UserPostSummary ups
LEFT JOIN 
    RankedPosts rp ON ups.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPostHistory rph ON ups.UserId = rph.UserDisplayName 
WHERE 
    ups.Reputation > 100 AND (rp.Score IS NOT NULL OR rp.PostId IS NOT NULL)
GROUP BY 
    ups.UserId, ups.DisplayName, ups.Reputation, ups.TotalScore, ups.PostCount
ORDER BY 
    ups.TotalScore DESC;
