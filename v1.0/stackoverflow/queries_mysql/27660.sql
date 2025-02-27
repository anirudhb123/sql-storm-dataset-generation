
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 
            @row := @row + 1 AS n
        FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS n,
            (SELECT @row := 0) AS r
    ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
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
    LIMIT 10
), 
RecentVotes AS (
    SELECT 
        v.PostId, 
        COUNT(v.Id) AS VoteCount, 
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL 30 DAY
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
    LIMIT 5
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
