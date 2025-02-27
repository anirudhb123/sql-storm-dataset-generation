
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        value AS Tag
    FROM 
        Posts p 
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    WHERE 
        p.PostTypeId = 1
), 
TagStatistics AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount,
        COUNT(DISTINCT pt.PostId) AS PostCount
    FROM 
        PostTagCounts pt
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
), 
RecentVotes AS (
    SELECT 
        v.PostId, 
        COUNT(v.Id) AS VoteCount, 
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY 
        v.PostId
), 
PopularPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount, 
        p.AnswerCount
    FROM 
        Posts p
    JOIN 
        RecentVotes rv ON p.Id = rv.PostId
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        rv.VoteCount DESC, 
        p.ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.AnswerCount,
    ts.Tag AS TopTag,
    ts.TagCount
FROM 
    PopularPosts pp
JOIN 
    TagStatistics ts ON ts.PostCount >= 1
ORDER BY 
    pp.ViewCount DESC, 
    ts.TagCount DESC;
