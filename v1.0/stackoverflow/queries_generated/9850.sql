WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
CombinedSummary AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.TotalPosts,
        us.TotalComments,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CommentCount,
        ps.CloseCount
    FROM UserScoreSummary us
    JOIN PostSummary ps ON us.TotalPosts > 0
)
SELECT 
    UserId,
    DisplayName,
    TotalUpVotes,
    TotalDownVotes,
    TotalPosts,
    TotalComments,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostId,
    Title,
    CreationDate,
    UpVoteCount,
    DownVoteCount,
    CommentCount,
    CloseCount
FROM CombinedSummary
ORDER BY TotalUpVotes DESC, TotalPosts DESC
LIMIT 20;
