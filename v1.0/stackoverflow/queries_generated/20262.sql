WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(p.Id) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM 
        Users u
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ur.Reputation,
        ur.ReputationLevel,
        pvc.UpVotes,
        pvc.DownVotes,
        rp.TotalPosts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    WHERE 
        rp.rn = 1 -- Get the latest post for each user
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ReputationLevel,
    COALESCE(pd.UpVotes, 0) AS UpVotes,
    COALESCE(pd.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN pd.TotalPosts = 0 THEN 'No posts'
        WHEN pd.TotalPosts > 1 THEN 'Multiple posts'
        ELSE 'Single post'
    END AS PostsClassification,
    CONCAT(pd.Title, ' - ', pd.ReputationLevel) AS TitleWithReputation
FROM 
    PostDetails pd
WHERE 
    pd.Reputation IS NOT NULL
ORDER BY 
    pd.CreationDate DESC;

This SQL query accomplishes several advanced tasks:
1. **Common Table Expressions (CTEs)**: It uses multiple CTEs to break down the logic into manageable parts, including `RankedPosts`, `UserReputation`, and `PostVoteCounts`.
2. **Window Functions**: It employs `ROW_NUMBER()` and `COUNT()` to rank posts and count total posts per user.
3. **LEFT JOINs**: It combines results from different sources through outer joins for comprehensive results.
4. **Conditional Logic**: It has CASE expressions to categorize users by reputation and classify posts.
5. **COALESCE**: This is used to ensure that NULL values are handled appropriately.
6. **String Manipulation**: It concatenates strings to provide a richer output.
7. **Complex Predicates**: The WHERE clause filters efficiently while considering various classifications. 

This query could be used for performance benchmarking and showcases how to use various SQL constructs effectively.
