WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        CASE 
            WHEN p.LastEditDate IS NULL THEN 'Not Edited' 
            ELSE 'Edited' 
        END AS EditStatus
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.LastEditDate
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.AnswerCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.EditStatus,
        CASE 
            WHEN rp.Score >= 10 THEN 'High Score' 
            WHEN rp.Score BETWEEN 5 AND 9 THEN 'Medium Score' 
            ELSE 'Low Score' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.AnswerCount > 5
),
FinalResult AS (
    SELECT 
        pp.*,
        U.DisplayName AS OwnerDisplayName,
        (SELECT STRING_AGG(CONCAT(t.TagName), ', ') 
         FROM Tags t 
         JOIN PostTags pt ON t.Id = pt.TagId 
         WHERE pt.PostId = pp.Id) AS TagsList
    FROM 
        PopularPosts pp
    LEFT JOIN 
        Users U ON pp.OwnerUserId = U.Id
)
SELECT 
    Id,
    Title,
    Score,
    AnswerCount,
    UpVoteCount,
    DownVoteCount,
    EditStatus,
    ScoreCategory,
    OwnerDisplayName,
    TagsList
FROM 
    FinalResult
WHERE 
    EditStatus = 'Edited'
ORDER BY 
    Score DESC, CreationDate ASC;
