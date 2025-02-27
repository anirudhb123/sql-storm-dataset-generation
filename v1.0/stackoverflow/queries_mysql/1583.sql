
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
         UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags)
         -CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseHistory
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.TotalViews,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.UserRank,
    pt.TagName,
    pt.TagCount,
    COALESCE(cp.CloseHistory, 0) AS CloseHistory
FROM 
    UserActivity ua
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, (SELECT GROUP_CONCAT(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) SEPARATOR ',') 
                                                  FROM Posts 
                                                  JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                                                        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
                                                        UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags)
                                                         -CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1 
                                                  WHERE OwnerUserId = ua.UserId)))
LEFT JOIN 
    ClosedPosts cp ON cp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
WHERE 
    ua.TotalPosts > 5
ORDER BY 
    ua.UserRank, pt.TagCount DESC
LIMIT 100;
