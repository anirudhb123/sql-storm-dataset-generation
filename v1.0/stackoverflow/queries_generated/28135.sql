WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostKeywordStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS Tag
    FROM Posts p
    WHERE p.CreatedDate > NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(PostId) AS TagCount
    FROM PostKeywordStats
    GROUP BY Tag
    ORDER BY TagCount DESC
    LIMIT 10
),
PostInteractions AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY p.Id, p.Title
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.AcceptedAnswers,
    us.TotalBounty,
    pt.Tag AS PopularTag,
    pt.TagCount,
    pi.PostId,
    pi.Title,
    pi.CommentCount,
    pi.UniqueVoters,
    pi.UpVotes,
    pi.DownVotes
FROM UserStats us
JOIN PopularTags pt ON pt.Tag IN (
    SELECT UNNEST(STRING_TO_ARRAY(us.TotalPosts, ','))
)
LEFT JOIN PostInteractions pi ON pi.CommentCount > 5
ORDER BY us.Reputation DESC, pt.TagCount DESC;
