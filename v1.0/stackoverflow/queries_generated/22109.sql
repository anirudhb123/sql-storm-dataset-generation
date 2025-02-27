WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COALESCE(NULLIF(u.Reputation, 0), 1) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
PostActivity AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId
),
PostSummary AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        p.UserReputation,
        CASE 
            WHEN pa.UpVotes > pa.DownVotes THEN 'Positive'
            WHEN pa.UpVotes < pa.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment,
        CASE 
            WHEN (p.UserReputation > 1000 AND pa.CommentCount > 5) THEN 'Highly Active Contributor'
            WHEN (p.UserReputation <= 1000 AND pa.CommentCount <= 5) THEN 'Novice Contributor'
            ELSE 'Moderately Active Contributor'
        END AS ContributorLevel
    FROM 
        PostActivity pa
    JOIN 
        RankedPosts p ON pa.PostId = p.PostId
    WHERE 
        p.RankByScore <= 5
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.VoteSentiment,
    ps.ContributorLevel,
    CASE 
        WHEN ps.VoteSentiment = 'Negative' 
            THEN 'Consider moderation to engage more'
        ELSE 'Keep up the good work!'
    END AS EngagementStrategy
FROM 
    PostSummary ps
ORDER BY 
    ps.CreationDate DESC
OPTION (RECOMPILE);

This query aims to analyze the top posts (within the last year) based on various metrics such as user engagement and sentiment derived from the scores of upvotes and downvotes. It employs multiple CTEs, utilizes window functions for ranking posts, and applies conditional logic based on metrics computed during the analysis. Additionally, it provides strategic feedback on engagement based on user contributions.
