WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),

PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

FinalBenchmark AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        pt.TagName,
        ur.DisplayName AS UserName,
        ur.Reputation,
        ur.QuestionsAsked,
        ur.AnswersGiven
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'
    JOIN 
        UserReputation ur ON ur.UserId = rp.OwnerUserId
    WHERE 
        rp.rn = 1 -- Only select the top row per post
)

SELECT 
    fb.PostId,
    fb.Title,
    fb.Body,
    fb.Tags,
    fb.CreationDate,
    fb.OwnerDisplayName,
    fb.AnswerCount,
    fb.UpVotes,
    fb.DownVotes,
    fb.TagName,
    fb.UserName,
    fb.Reputation,
    fb.QuestionsAsked,
    fb.AnswersGiven
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.CreationDate DESC
LIMIT 50;
