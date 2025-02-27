
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @rownum := IF(@prevOwnerUserId = p.OwnerUserId, @rownum + 1, 1) AS Rank,
        @prevOwnerUserId := p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    CROSS JOIN (SELECT @rownum := 0, @prevOwnerUserId := NULL) r
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  
),

TagStatistics AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
         FROM Posts p
         INNER JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
                     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
        ) tag ON p.PostTypeId = 1
    GROUP BY 
        tag.TagName
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.ViewCount,
    fp.Score,
    ts.TagName,
    ts.PostCount,
    ts.AverageViewCount,
    ts.AverageScore
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagStatistics ts ON FIND_IN_SET(ts.TagName, TRIM(BOTH '<>' FROM REPLACE(fp.Tags, '><', '>')) )
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;
