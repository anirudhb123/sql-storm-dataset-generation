WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Tags t ON POSITION(',' || t.TagName || ',' IN ',' || p.Tags || ',') > 0
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
VoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeleteVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Id,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Tags,
    vu.DisplayName AS MostActiveUser,
    vs.UpVotes,
    vs.DownVotes,
    vs.DeleteVotes
FROM 
    RankedPosts rp
JOIN 
    MostActiveUsers vu ON RP.ViewCount > 100 -- Example check for high engagement
JOIN 
    VoteSummary vs ON rp.Id = vs.PostId
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
