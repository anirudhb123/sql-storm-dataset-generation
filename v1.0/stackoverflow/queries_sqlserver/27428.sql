
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
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
        AND p.Score > 0 
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS NumberOfPosts
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>') 
    WHERE
        PostTypeId = 1 
    GROUP BY 
        value
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
    PopularTags pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(ttp.Title, 2, LEN(ttp.Title) - 2), '>'))
WHERE 
    ttp.OverallRanking <= 10 
ORDER BY 
    ttp.Score DESC, ttp.ViewCount DESC;
