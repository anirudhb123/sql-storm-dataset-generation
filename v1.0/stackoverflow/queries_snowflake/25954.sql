
WITH TagUsage AS (
    SELECT 
        SPLIT(Tags, '><') AS TagArray,
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        U.Reputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users U ON U.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = U.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.OwnerUserId, p.CreationDate, p.Title, U.Reputation, Tags
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS QuestionCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        SUM(CommentCount) AS TotalComments,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        TagUsage,
        LATERAL FLATTEN(Input => TagArray) AS Tag
    GROUP BY 
        Tag
),
RankedTags AS (
    SELECT 
        Tag,
        QuestionCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalComments,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC, TotalUpVotes DESC) AS Rank
    FROM 
        TagStats
)

SELECT 
    Tag,
    QuestionCount,
    TotalUpVotes,
    TotalDownVotes,
    TotalComments,
    TotalBadges,
    Rank
FROM 
    RankedTags
WHERE 
    Rank <= 10 
ORDER BY 
    Rank;
