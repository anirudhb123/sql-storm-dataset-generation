
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 1 YEAR) 
        AND p.Score > 0
),

TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),

PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
         FROM 
            (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers
         WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.TagName 
    GROUP BY 
        p.Id
)

SELECT 
    q.PostId,
    q.Title,
    q.Score,
    q.OwnerDisplayName,
    vc.VoteCount,
    vc.UpVotes,
    vc.DownVotes,
    pt.Tags
FROM 
    TopQuestions q
LEFT JOIN 
    PostVoteCounts vc ON q.PostId = vc.PostId
LEFT JOIN 
    PostTags pt ON q.PostId = pt.PostId
ORDER BY 
    q.Score DESC;
