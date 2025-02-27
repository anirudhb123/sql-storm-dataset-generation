
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE( (
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2 
        ), 0) AS UpVotes,
        COALESCE( (
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3 
        ), 0) AS DownVotes,
        @row_num := IF(@prev_tag = p.Tags, @row_num + 1, 1) AS TagRank,
        @prev_tag := p.Tags
    FROM 
        Posts p
    JOIN 
        Users U ON U.Id = p.OwnerUserId,
        (SELECT @row_num := 0, @prev_tag := '') AS r
    WHERE 
        p.PostTypeId = 1 
),

FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.Tags,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.UpVotes,
        RP.DownVotes
    FROM 
        RankedPosts RP
    WHERE 
        RP.TagRank <= 5 
),

AggregatedData AS (
    SELECT 
        FP.Tags,
        COUNT(FP.PostId) AS TotalQuestions,
        SUM(FP.UpVotes) AS TotalUpVotes,
        SUM(FP.DownVotes) AS TotalDownVotes,
        AVG(FP.UpVotes - FP.DownVotes) AS AverageScore
    FROM 
        FilteredPosts FP
    GROUP BY 
        FP.Tags
),

FinalResults AS (
    SELECT 
        AD.Tags,
        AD.TotalQuestions,
        AD.TotalUpVotes,
        AD.TotalDownVotes,
        AD.AverageScore,
        (AD.TotalUpVotes + AD.TotalDownVotes) AS TotalVotes
    FROM 
        AggregatedData AD
    ORDER BY 
        TotalVotes DESC
    LIMIT 10 
)

SELECT 
    FR.Tags,
    FR.TotalQuestions,
    FR.TotalUpVotes,
    FR.TotalDownVotes,
    FR.AverageScore
FROM 
    FinalResults FR;
