WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ph.Comment, 'No Comments') AS PostHistoryComment,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, ph.Comment
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.CreationDate,
        pd.PostHistoryComment,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        CASE 
            WHEN pd.CommentCount > 0 THEN ROUND(COALESCE(pd.UpVotes, 0)::decimal / NULLIF(pd.CommentCount, 0), 2)
            ELSE 0
        END AS UpVoteToCommentRatio,
        RANK() OVER (ORDER BY pd.UpVotes DESC) AS TopRank
    FROM 
        PostDetails pd
    WHERE 
        pd.ViewRank <= 100
),
UserTopPosts AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        tp.Title,
        tp.UpVotes,
        tp.CommentCount,
        tp.UpVoteToCommentRatio
    FROM 
        UserReputation ur
    JOIN 
        Posts p ON p.OwnerUserId = ur.UserId
    JOIN 
        TopPosts tp ON tp.PostId = p.Id
)
SELECT 
    utp.UserId,
    u.DisplayName,
    utp.Reputation,
    ARRAY_AGG(utp.Title) AS PostTitles,
    SUM(utp.UpVotes) AS TotalUpVotes,
    SUM(utp.CommentCount) AS TotalComments,
    AVG(utp.UpVoteToCommentRatio) AS AvgUpVoteToCommentRatio
FROM 
    UserTopPosts utp
JOIN 
    Users u ON u.Id = utp.UserId
GROUP BY 
    utp.UserId, u.DisplayName, utp.Reputation
HAVING 
    AVG(utp.UpVoteToCommentRatio) > 1.5
ORDER BY 
    TotalUpVotes DESC
LIMIT 10;

This SQL query performs the following tasks:
1. **User Reputations**: A CTE (`UserReputation`) selects user IDs and their reputations, assigning ranks based on reputation.
2. **Post Details**: Another CTE (`PostDetails`) gathers information about each post, including title, view count, creation date, and aggregated comment statistics.
3. **Top Posts**: Filters the `PostDetails` to select the top posts based on view count and calculates the upvote-to-comment ratio.
4. **User Top Posts**: Joins `UserReputation` with posts to accumulate data specific to each top user's posts.
5. **Final Selection**: The main query aggregates the results by user, providing insight into user contributions while applying complex conditions and calculations.

It leverages multiple SQL constructs like CTEs, aggregate functions, window functions, and dealing with NULL values in creative ways to benchmark performance effectively.
