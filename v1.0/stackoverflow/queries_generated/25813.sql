WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        LastActivityDate,
        OwnerDisplayName,
        AnswerCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        LastActivityDate >= NOW() - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsPosted,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived,
        SUM(v.VoteTypeId = 3) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.Tags,
    us.QuestionsPosted,
    us.AnswersPosted,
    us.UpVotesReceived,
    us.DownVotesReceived
FROM 
    RecentPosts rp
JOIN 
    UserStats us ON rp.OwnerDisplayName = us.Id
ORDER BY 
    rp.LastActivityDate DESC, us.QuestionsPosted DESC;
