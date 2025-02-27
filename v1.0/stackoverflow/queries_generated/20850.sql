WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate > NOW() - INTERVAL '1 month'
    GROUP BY
        p.Id
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(rp.CommentCount), 0) AS TotalCommentCount,
        COALESCE(SUM(rp.TotalUpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(rp.TotalDownVotes), 0) AS TotalDownVotes,
        COUNT(DISTINCT rp.PostId) AS TotalPosts
    FROM
        Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY
        u.Id
),
HighEngagementUsers AS (
    SELECT
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.TotalCommentCount,
        ue.TotalUpVotes,
        ue.TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY ue.TotalCommentCount DESC, ue.TotalUpVotes DESC) AS EngagementRank
    FROM
        UserEngagement ue
    WHERE
        ue.TotalPosts > 0
    HAVING
        ue.TotalCommentCount > 10
)

SELECT
    u.Location,
    u.AboutMe,
    he.DisplayName,
    he.TotalPosts,
    he.TotalComments,
    he.TotalUpVotes,
    he.TotalDownVotes,
    CASE 
        WHEN u.Reputation < 100 THEN 'Newbie'
        WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Contributor'
        ELSE 'Expert'
    END AS ReputationLevel
FROM
    HighEngagementUsers he
JOIN
    Users u ON he.UserId = u.Id
WHERE
    u.Location IS NOT NULL
    AND u.Location <> ''
ORDER BY
    he.EngagementRank, u.Reputation DESC
LIMIT 10;

WITH CommentAnalytics AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        MAX(c.CreationDate) AS LastCommentDate
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY
        p.Id
),
RelatedPostLinks AS (
    SELECT
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS RelationType
    FROM
        PostLinks pl
    JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE
        lt.Name IN ('Duplicate', 'Linked')
)
SELECT
    ca.PostId,
    ca.TotalComments,
    ca.LastCommentDate,
    rpl.RelatedPostId,
    rpl.RelationType
FROM
    CommentAnalytics ca
LEFT JOIN RelatedPostLinks rpl ON ca.PostId = rpl.PostId
WHERE
    ca.TotalComments > 5
    AND (EXTRACT(DAY FROM NOW() - ca.LastCommentDate) < 30 OR rpl.RelatedPostId IS NOT NULL)
ORDER BY
    ca.TotalComments DESC, ca.LastCommentDate DESC
LIMIT 25;

-- Optional analytics based on null logic:
WITH PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(NULLIF(p.Tags, ''), 'No Tags') AS Tags,
        CASE 
            WHEN p.ViewCount IS NULL THEN 0 
            ELSE p.ViewCount 
        END AS ViewCountAdjust
    FROM 
        Posts p
)
SELECT 
    Tags,
    COUNT(*) AS PostCount,
    AVG(ViewCountAdjust) AS AvgViews
FROM 
    PostsWithTags
GROUP BY 
    Tags
HAVING 
    COUNT(*) > 1
ORDER BY 
    AvgViews DESC;
