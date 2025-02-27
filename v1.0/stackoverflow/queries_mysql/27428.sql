
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND p.Score > 0 
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS NumberOfPosts
    FROM 
        Posts
    CROSS JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers
    WHERE
        PostTypeId = 1 
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 
),
TopTenPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS OverallRanking
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id 
    WHERE 
        rp.RankByTag = 1 
)
SELECT 
    ttp.PostId,
    ttp.Title,
    ttp.OwnerName,
    ttp.Score,
    ttp.ViewCount,
    ttp.AnswerCount,
    ttp.CommentCount,
    pt.TagName AS PostTypeName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ttp.PostId) AS TotalComments,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ttp.PostId AND v.VoteTypeId = 2) AS TotalUpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ttp.PostId AND v.VoteTypeId = 3) AS TotalDownVotes
FROM 
    TopTenPosts ttp
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, SUBSTRING_INDEX(SUBSTRING_INDEX(ttp.Title, '>', -1), '>', -1)) > 0
WHERE 
    ttp.OverallRanking <= 10 
ORDER BY 
    ttp.Score DESC, ttp.ViewCount DESC;
