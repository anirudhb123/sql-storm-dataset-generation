WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.Id
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) ) AS TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(p.Id) > 5 -- Tags with more than 5 questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON u.Id = c.UserId
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.TagName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.TotalUpVotes,
    ua.TotalDownVotes
FROM 
    RankedPosts rp
    LEFT JOIN PopularTags pt ON pt.PostCount > 5
    LEFT JOIN UserActivity ua ON rp.OwnerDisplayName = ua.DisplayName
WHERE 
    rp.PostRank = 1 -- Only top post per user
ORDER BY 
    rp.LastActivityDate DESC; 
