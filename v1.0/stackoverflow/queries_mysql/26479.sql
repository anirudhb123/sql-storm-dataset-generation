
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON FIND_IN_SET(t.TagName, REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><', ','), '>', ''))
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 MONTH 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags, pt.Name
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    TagList,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    CASE 
        WHEN Rank <= 5 THEN 'Top'
        WHEN Rank BETWEEN 6 AND 15 THEN 'Mid'
        ELSE 'Low' 
    END AS RankCategory
FROM 
    RankedPosts
WHERE 
    Rank <= 15 
ORDER BY 
    Score DESC, ViewCount DESC;
