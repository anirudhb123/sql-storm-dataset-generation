WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.OwnerUserId) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.OwnerUserId) AS DownVotesCount,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId) AS ClosedPostCount
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
),

UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount,
        MAX(rp.Score) AS MaxScore,
        MIN(rp.Score) AS MinScore,
        COALESCE(SUM(rp.UpVotesCount) - SUM(rp.DownVotesCount), 0) AS NetVotes,
        MAX(rp.ClosedPostCount) AS ClosedPosts
    FROM
        Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.PostRank
    GROUP BY
        u.Id, u.DisplayName
),

PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate
    FROM
        PostHistory ph
    INNER JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
),

FinalMetrics AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalScore,
        ups.AvgViewCount,
        ups.MaxScore,
        ups.MinScore,
        ups.NetVotes,
        ups.ClosedPosts,
        COALESCE(ph.LastClosedDate, ph.LastReopenedDate) AS LastActivityDate,
        CASE
            WHEN COUNT(DISTINCT ph.PostId) = 0 THEN 'Never Active'
            WHEN MAX(COALESCE(ph.LastClosedDate, ph.LastReopenedDate) IS NOT NULL) THEN 'Recently Active'
            ELSE 'Inactive'
        END AS ActivityStatus
    FROM
        UserPostStats ups
    LEFT JOIN PostHistoryDetails ph ON ups.UserId = ph.UserId
    GROUP BY
        ups.UserId, ups.DisplayName, ups.TotalPosts, ups.TotalScore, ups.AvgViewCount, ups.MaxScore, ups.MinScore, ups.NetVotes, ups.ClosedPosts
)

SELECT 
    *
FROM 
    FinalMetrics
WHERE 
    TotalScore > 0
    AND AvgViewCount > (SELECT AVG(AvgViewCount) FROM UserPostStats)
    AND ActivityStatus = 'Recently Active'
ORDER BY 
    TotalScore DESC, TotalPosts DESC
LIMIT 10;
