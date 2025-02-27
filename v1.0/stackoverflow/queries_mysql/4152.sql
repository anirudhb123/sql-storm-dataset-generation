
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostActivity AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS RecentPostNumber,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8,
        (SELECT @row_number := 0, @current_user := 0) r
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpVotes,
    us.TotalDownVotes,
    pt.TagName AS PopularTag,
    pa.Title AS RecentPostTitle,
    pa.CreationDate AS PostCreationDate,
    pa.CommentCount,
    pa.TotalBounty
FROM 
    UserStatistics us
JOIN 
    PopularTags pt ON 1=1
JOIN 
    PostActivity pa ON us.UserId = pa.OwnerUserId
WHERE 
    us.Reputation > 1000
    AND (pa.RecentPostNumber = 1 OR pa.RecentPostNumber IS NULL)
ORDER BY 
    us.Reputation DESC,
    pa.TotalBounty DESC
LIMIT 50;
