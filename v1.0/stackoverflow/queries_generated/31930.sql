WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 /* Only questions */
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        MAX(rp.Score) AS MaxPostScore,
        SUM(rp.ViewCount) AS TotalViews,
        COUNT(rp.PostId) AS TotalPosts,
        AVG(rp.Score) AS AvgPostScore,
        CASE 
            WHEN SUM(rp.ViewCount) > 1000 THEN 'High Engagement'
            WHEN SUM(rp.ViewCount) BETWEEN 500 AND 1000 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentVotes AS (
    SELECT 
        v.UserId,
        v.PostId,
        v.CreationDate,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days' /* Recent votes in the last 30 days */
    GROUP BY 
        v.UserId, v.PostId, v.CreationDate, vt.Name
),
EngagementSummary AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.Reputation,
        ups.MaxPostScore,
        ups.TotalViews,
        ups.TotalPosts,
        ups.AvgPostScore,
        ups.EngagementLevel,
        JSON_AGG(rv) AS RecentVotesData
    FROM 
        UserPostStats ups
    LEFT JOIN 
        RecentVotes rv ON ups.UserId = rv.UserId
    GROUP BY 
        ups.UserId, ups.DisplayName, ups.Reputation, 
        ups.MaxPostScore, ups.TotalViews, ups.TotalPosts, 
        ups.AvgPostScore, ups.EngagementLevel
)
SELECT 
    es.UserId,
    es.DisplayName,
    es.Reputation,
    es.MaxPostScore,
    es.TotalViews,
    es.TotalPosts,
    es.AvgPostScore,
    es.EngagementLevel,
    COALESCE(ARRAY_LENGTH(es.RecentVotesData, 1), 0) AS NumberOfRecentVotes
FROM 
    EngagementSummary es
ORDER BY 
    es.TotalPosts DESC, es.Reputation DESC;
