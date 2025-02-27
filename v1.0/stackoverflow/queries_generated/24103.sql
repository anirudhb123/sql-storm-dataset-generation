WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(NULLIF(SUM(v.VoteTypeId = 1), 0), 'Not Applicable') AS AcceptedPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankWithinUser
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
EnhancedPostStats AS (
    SELECT 
        pd.*,
        UPPER(pd.Title) AS UpperCaseTitle,
        CASE 
            WHEN pd.Score IS NULL OR pd.Score < 0 THEN 'Negative'
            WHEN pd.Score = 0 THEN 'Neutral'
            ELSE 'Positive'
        END AS ScoreCategory
    FROM 
        PostDetails pd
    WHERE 
        pd.PostId IN (
            SELECT DISTINCT pl.RelatedPostId
            FROM PostLinks pl
            WHERE pl.LinkTypeId = 1
        )
),
FinalResults AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.PostCount,
        SUM(eps.ViewCount) AS TotalViewCount,
        AVG(eps.Score) AS AvgScore,
        STRING_AGG(eps.UpperCaseTitle, ', ') AS PostTitles,
        COUNT(eps.PostId) AS TotalPostsRanked,
        MAX(eps.RankWithinUser) AS MaxRank,
        COUNT(CASE WHEN eps.ScoreCategory = 'Positive' THEN 1 END) AS PositiveScoreCount
    FROM 
        UserStats us
    LEFT JOIN 
        EnhancedPostStats eps ON us.UserId = eps.OwnerUserId
    GROUP BY 
        us.UserId, us.Reputation, us.PostCount
)
SELECT 
    *,
    CASE 
        WHEN TotalViewCount IS NULL THEN 'No Views Recorded'
        WHEN AvgScore > 0 THEN 'Above Average Contributor'
        ELSE 'Needs Improvement'
    END AS ContributorStatus
FROM 
    FinalResults
WHERE 
    TotalPostsRanked > 5
ORDER BY 
    Reputation DESC, TotalViewCount DESC;
