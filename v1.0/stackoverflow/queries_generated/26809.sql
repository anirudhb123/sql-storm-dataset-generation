WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerDisplayName, p.Tags
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        U.Reputation,
        U.EmailHash,
        CASE 
            WHEN rp.AnswerCount > 0 THEN 'Answered'
            ELSE 'Unanswered'
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        Users U ON rp.Rank = 1 AND U.Id = rp.OwnerUserId
    WHERE 
        rp.CreationDate > DATEADD(DAY, -30, GETDATE())
)
SELECT 
    PostStatus,
    COUNT(*) AS PostCount,
    AVG(answerCount * 1.0) AS AvgAnswerCount,
    AVG(UpVotes * 1.0) AS AvgUpVotes,
    AVG(DownVotes * 1.0) AS AvgDownVotes,
    STRING_AGG(Title, '; ') AS Titles
FROM 
    RecentPosts
GROUP BY 
    PostStatus
ORDER BY 
    PostStatus DESC;
