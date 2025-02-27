
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1)) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
               SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
               SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserRankedComments AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.TagsArray,
        COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS UserCommentCount,
        COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL AND c.UserDisplayName IS NOT NULL THEN 1 ELSE 0 END), 0) AS ValidCommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostID = c.PostId
    GROUP BY 
        rp.PostID, rp.Title, rp.TagsArray
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    SUM(uc.UserCommentCount) AS TotalUserComments,
    AVG(uc.ValidCommentCount) AS AverageValidComments,
    GROUP_CONCAT(DISTINCT uc.TagsArray) AS UniqueTags
FROM 
    Users up
JOIN 
    UserRankedComments uc ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = uc.PostID)
GROUP BY 
    up.Id, up.DisplayName
HAVING 
    SUM(uc.UserCommentCount) > 0
ORDER BY 
    TotalUserComments DESC
LIMIT 10;
