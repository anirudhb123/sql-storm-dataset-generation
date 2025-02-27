
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
),
QuestionStats AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.Author,
        r.Tags,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        RankedPosts r
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        Votes v ON r.PostId = v.PostId
    WHERE 
        r.PostRank = 1  
    GROUP BY 
        r.PostId, r.Title, r.CreationDate, r.ViewCount, r.Score, r.Author, r.Tags
),
FinalResults AS (
    SELECT 
        qs.PostId,
        qs.Title,
        qs.CreationDate,
        qs.ViewCount,
        qs.Score,
        qs.Author,
        qs.Tags,
        qs.TotalCommentScore,
        qs.UpVotes,
        qs.DownVotes,
        (qs.UpVotes - qs.DownVotes) AS VoteDifference
    FROM 
        QuestionStats qs
)
SELECT 
    * 
FROM 
    FinalResults
WHERE 
    VoteDifference > 0  
ORDER BY 
    VoteDifference DESC, 
    ViewCount DESC;
